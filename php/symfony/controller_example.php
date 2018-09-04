<?php

namespace AppBundle\Controller;

use AppBundle\Entity\Sheet;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Method;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Component\HttpFoundation\Request;

/**
 * Sheet controller.
 *
 * @Route("sheet")
 */
class SheetController extends Controller
{
    /**
     * Lists all sheet entities.
     *
     * @Route("/", name="sheet_index")
     * @Method({"GET", "POST"})
     */
    public function indexAction(Request $request)
    {
        $em = $this->getDoctrine()->getManager();
        $repository = $em->getRepository('AppBundle:Sheet');

        if($request->isMethod('POST')) {
            $month = $request->get("month");
            $year = $request->get("year");
            
            if($month == null && $year == null) {
                $sheets = $repository->findAll();;
            } else {
                if($month == null && $year != null) {
                    $filter = "p.year = " . $year;
                } else if($year == null && $month != null) {
                    $filter = "p.month = " . $month;
                } else {
                    $filter = "p.month = " . $month . " and p.year = " . $year; 
                }

                $query = $repository->createQueryBuilder('p')
                    ->where($filter)
                    ->getQuery();
                $sheets = $query->getResult();
            }
        } else {
            $query = $repository->createQueryBuilder('p')
                ->where("p.month = " . (int)date("m") . " and p.year = " . (int)date("Y"))
                ->getQuery();
            $sheets = $query->getResult();
        }

        return $this->render('sheet/index.html.twig', array(
            'sheets' => $sheets,
        ));
    }

    /**
     * Creates a new sheet entity.
     *
     * @Route("/new", name="sheet_new")
     * @Method({"GET", "POST"})
     */
    public function newAction(Request $request)
    {
        $sheet = new Sheet();
        $form = $this->createForm('AppBundle\Form\SheetType', $sheet);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            $em = $this->getDoctrine()->getManager();
            $em->persist($sheet);
            $em->flush();

            return $this->redirectToRoute('sheet_show', array('id' => $sheet->getId()));
        }

        return $this->render('sheet/new.html.twig', array(
            'sheet' => $sheet,
            'form' => $form->createView(),
        ));
    }

    /**
     * Finds and displays a sheet entity.
     *
     * @Route("/{id}", name="sheet_show")
     * @Method("GET")
     */
    public function showAction(Sheet $sheet)
    {
        $deleteForm = $this->createDeleteForm($sheet);

        return $this->render('sheet/show.html.twig', array(
            'sheet' => $sheet,
            'delete_form' => $deleteForm->createView(),
        ));
    }

    /**
     * Displays a form to edit an existing sheet entity.
     *
     * @Route("/{id}/edit", name="sheet_edit")
     * @Method({"GET", "POST"})
     */
    public function editAction(Request $request, Sheet $sheet)
    {
        $deleteForm = $this->createDeleteForm($sheet);
        $editForm = $this->createForm('AppBundle\Form\SheetType', $sheet);
        $editForm->handleRequest($request);

        if ($editForm->isSubmitted() && $editForm->isValid()) {
            $this->getDoctrine()->getManager()->flush();

            return $this->redirectToRoute('sheet_show', array('id' => $sheet->getId()));
        }

        return $this->render('sheet/edit.html.twig', array(
            'sheet' => $sheet,
            'edit_form' => $editForm->createView(),
            'delete_form' => $deleteForm->createView(),
        ));
    }

    /**
     * Deletes a sheet entity.
     *
     * @Route("/{id}", name="sheet_delete")
     * @Method("DELETE")
     */
    public function deleteAction(Request $request, Sheet $sheet)
    {
        $form = $this->createDeleteForm($sheet);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            $em = $this->getDoctrine()->getManager();
            $em->remove($sheet);
            $em->flush();
        }

        return $this->redirectToRoute('sheet_index');
    }

    /**
     * Creates a form to delete a sheet entity.
     *
     * @param Sheet $sheet The sheet entity
     *
     * @return \Symfony\Component\Form\Form The form
     */
    private function createDeleteForm(Sheet $sheet)
    {
        return $this->createFormBuilder()
            ->setAction($this->generateUrl('sheet_delete', array('id' => $sheet->getId())))
            ->setMethod('DELETE')
            ->getForm()
        ;
    }
}